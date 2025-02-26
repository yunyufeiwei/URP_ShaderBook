using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MotionBlurWithDepthTexturePass : ScriptableRenderPass
{
    static readonly string RenderTag = "MotionBlur";               //新建渲染事件的名称
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //该ID用来和sourceRT进行绑定，使用ID来属性来计算是为了提高性能
    static readonly int tempTexID = Shader.PropertyToID("_tempRT");

    Material m_material;
    Matrix4x4 previousViewProjectionMatrix;
    MotionBlurWithDepthTextureVolume volume;

    RenderTargetIdentifier source;              //设置当前渲染目标纹理
    RTHandle buffer01;
    public FilterMode filterMode {get;set;}

    public MotionBlurWithDepthTexturePass(RenderPassEvent passEvent, Shader m_shader)
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
        volume = stack.GetComponent<MotionBlurWithDepthTextureVolume>();
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
        
        Camera camera = renderingData.cameraData.camera;

        m_material.SetFloat("_BlurSize" , volume.BlurSize.value);
        m_material.SetMatrix("_PreviousViewProjectionMatrix" , previousViewProjectionMatrix);
        
        Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
        Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
        m_material.SetMatrix("_CurrentViewProjectionInverseMatrix" , currentViewProjectionInverseMatrix);
        previousViewProjectionMatrix = currentViewProjectionMatrix;

        //创建临时RT
        RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
        cameraTextureDesc.depthBufferBits = 0;
        int rtWidth = cameraTextureDesc.width;
        int rtHeight = cameraTextureDesc.height;

        cmd.SetGlobalTexture(MainTexID, source);
        cmd.GetTemporaryRT(tempTexID , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);

        cmd.Blit(source , tempTexID , m_material , 0);
        cmd.Blit(tempTexID , source);

        cmd.ReleaseTemporaryRT(tempTexID);
    }
}
