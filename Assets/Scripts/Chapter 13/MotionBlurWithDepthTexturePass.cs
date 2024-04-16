using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MotionBlurWithDepthTexturePass : ScriptableRenderPass
{
    private static readonly string Tag = "MotionBlurWithDepthTexture";
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //设置渲染的主纹理
    private static readonly int tempTexID = Shader.PropertyToID("_MotionBlurWithDepthTexture");    //定义临时的存储的RT纹理  
    
    private Material m_material;
    private MotionBlurWithDepthTextureVoulme volume;

    private Matrix4x4 previousViewProjectionMatrix;
    
    private RenderTargetIdentifier source;
    private RTHandle buffer01;
    public FilterMode filterMode { get; set; }
    
    public MotionBlurWithDepthTexturePass(RenderPassEvent renderEvent, Shader m_shader)
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
        volume = stack.GetComponent<MotionBlurWithDepthTextureVoulme>();   //获取Volume上的组件上添加的脚本
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

        Camera camera = renderingData.cameraData.camera;
        
        m_material.SetFloat("_BlurSize",volume.blurSize.value);
        m_material.SetMatrix("_PreviousViewProjectionMatrix",previousViewProjectionMatrix);

        Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
        Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
        m_material.SetMatrix("_CurrentViewProjectionInverseMatrix",currentViewProjectionInverseMatrix);
        previousViewProjectionMatrix = currentViewProjectionMatrix;
        
        //申请临时RT，并定义宽度与高度
        RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
        cameraTextureDesc.depthBufferBits = 0;
        int rtWidth = cameraTextureDesc.width;     //定义临时RT的宽度
        int rtHeight = cameraTextureDesc.height;   //定义临时RT的高度
        
        cmd.SetGlobalTexture(MainTexID,source);
        cmd.GetTemporaryRT(tempTexID,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);
        
        cmd.Blit(source,tempTexID,m_material,0);
        cmd.Blit(tempTexID,source);
        
        cmd.ReleaseTemporaryRT(tempTexID);
    }
}
