using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogWithNoisePass : ScriptableRenderPass
{
    private static readonly string Tag = "FogWithNoise";
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //设置渲染的主纹理
    private static readonly int tempTexID = Shader.PropertyToID("_FogWithNoise");    //定义临时的存储的RT纹理 
    
    private Material m_material;
    private FogWithNoiseVolume volume;
    
    private RenderTargetIdentifier source;
    
    public FogWithNoisePass(RenderPassEvent renderEvent, Shader m_shader)
    {
        renderPassEvent = renderEvent;  //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;          //传入shader
        if(shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);      //通过指定的shader创建材质
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (m_material == null)
        {
            Debug.LogError("材质初始化失败！");
        }

        if (!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
        }
        
        //Volume相关
        var stack = VolumeManager.instance.stack;        //实例化volume到堆栈
        volume = stack.GetComponent<FogWithNoiseVolume>();   //获取Volume上的组件上添加的脚本
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败！");
            return;
        }
        
        CommandBuffer cmd = CommandBufferPool.Get(Tag);     //定义在FrameDebug里面渲染事件位置的名称
        OnRenderImage(cmd,renderingData);
        
        //上下文加入buffer
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    void OnRenderImage(CommandBuffer cmd, RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle; //获取当前相机的纹理
        
        //申请临时RT，并定义宽度与高度
        RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
        cameraTextureDesc.depthBufferBits = 0;
        int rtWidth = cameraTextureDesc.width;     //定义临时RT的宽度
        int rtHeight = cameraTextureDesc.height;   //定义临时RT的高度
        
        cmd.SetGlobalTexture(MainTexID,source);
        cmd.GetTemporaryRT(tempTexID,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);

        Camera camera = renderingData.cameraData.camera;
        Transform cameraTransform = camera.transform;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        Vector3 toTop = cameraTransform.up * halfHeight;

        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;
        
        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;
        
        Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
        bottomRight.Normalize();
        bottomRight *= scale;
        
        frustumCorners.SetRow(0,bottomLeft);
        frustumCorners.SetRow(1,bottomRight);
        frustumCorners.SetRow(2,topRight);
        frustumCorners.SetRow(3,topLeft);
        
        m_material.SetMatrix("_FrustumCornersRay",frustumCorners);
        m_material.SetFloat("_FogDensity",volume.FogDensity.value);
        m_material.SetColor("_FogColor",volume.FogColor.value);
        m_material.SetFloat("_FogStart",volume.FogStart.value);
        m_material.SetFloat("_FogEnd",volume.FogEnd.value);
        
        m_material.SetFloat("_FogXSpeed",volume.FogXSpeed.value);
        m_material.SetFloat("_FogYSpeed",volume.FogYSpeed.value);
        m_material.SetFloat("_NoiseAmount",volume.NoiseAmount.value);
        m_material.SetTexture("_NosieTex",volume.NoiseTex.value);
        
        cmd.Blit(source,tempTexID,m_material,0);
        cmd.Blit(tempTexID,source);
        
        cmd.ReleaseTemporaryRT(tempTexID);
    }
}
