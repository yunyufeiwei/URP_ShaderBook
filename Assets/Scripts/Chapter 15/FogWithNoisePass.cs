using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FogWithNoisePass : ScriptableRenderPass
{
    static readonly string RenderTag = "FogWithNosie";               //新建渲染事件的名称
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //该ID用来和sourceRT进行绑定，使用ID来属性来计算是为了提高性能
    static readonly int tempTexID = Shader.PropertyToID("_tempRT");

    Material m_material;
    FogWithNoiseVolume volume;

    RenderTargetIdentifier source;

    public FogWithNoisePass(RenderPassEvent passEvent, Shader m_shader)
    {
        renderPassEvent = passEvent;
        var shader = m_shader;
        if (shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);
    }   

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(m_material == null)
        {
            Debug.LogError("材质初始化创建失败!");
            return;
        }
        if(!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
            return;
        }

        var stack = VolumeManager.instance.stack;
        volume = stack.GetComponent<FogWithNoiseVolume>();
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(RenderTag);

        OnRenderImage(cmd, ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public void OnRenderImage(CommandBuffer cmd , ref RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;

        RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
        cameraTextureDesc.depthBufferBits = 0;
        int rtWidth = cameraTextureDesc.width;
        int rtHeight = cameraTextureDesc.height;

        cmd.SetGlobalTexture(MainTexID, source);
        cmd.GetTemporaryRT(tempTexID , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);

        Camera camera = renderingData.cameraData.camera;
        Transform cameraTransform = camera.transform;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fov = camera.fieldOfView;
        float near = camera.nearClipPlane;
        float aspect = camera.aspect;

        float halfHeight = near* Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toRight = cameraTransform.right * halfHeight * aspect;
        Vector3 toTop = cameraTransform.up * halfHeight;

        Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
        float scale = topLeft.magnitude / near;

        topLeft.Normalize();
        topLeft *=  scale;

        Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
        bottomRight.Normalize();
        bottomRight *= scale;

        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);

        m_material.SetMatrix("_FrustumCornersRay" , frustumCorners);
        
        m_material.SetFloat("_FogDensity" , volume.FogDensity.value);
        m_material.SetColor("_FogColor" , volume.FogColor.value);
        m_material.SetFloat("_FogStart" , volume.FogStart.value);
        m_material.SetFloat("_FogEnd",volume.FogEnd.value);

        m_material.SetFloat("_FogXSpeed" , volume.FogXSpeed.value);
        m_material.SetFloat("_FogYSpeed" , volume.FogYSpeed.value);
        m_material.SetFloat("_NoiseAmount", volume.NoiseAmount.value);
        m_material.SetTexture("_NoiseTex" , volume.NoiseTex.value); 

        cmd.Blit(source,tempTexID , m_material,0);
        cmd.Blit(tempTexID,source);

        cmd.ReleaseTemporaryRT(tempTexID);
    }
}
