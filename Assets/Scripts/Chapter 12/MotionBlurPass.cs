using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MotionBlurPass : ScriptableRenderPass
{
    #region  变量声明
    static readonly string RenderEventPassTag = "MotionBlur";                                    //新建渲染事件的名称
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");
    static readonly int tempTexID = Shader.PropertyToID("_tempRT");

    Material m_material;                  //新建材质
    MotionBlurVolume volume;              //新建Volume组件

    RenderTargetIdentifier source;                //设置当前渲染目标
    #endregion

    public MotionBlurPass(RenderPassEvent renderEvent , Shader m_shader )
    {
        renderPassEvent = renderEvent;      //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;
        if(shader == null){return;}
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

        //初始化阶段准备好Volumne数据
        var stack = VolumeManager.instance.stack;
        volume = stack.GetComponent<MotionBlurVolume>();
        if(volume == null)
        {
            Debug.LogError("Volume组件获取失败!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(RenderEventPassTag);      //拿到在FrameDebug里面渲染事件相关信息

        OnRenderImage(cmd , ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public RenderTexture tempRT;
    
    void OnRenderImage(CommandBuffer cmd , ref RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;     //获取当前相机的纹理

        RenderTextureDescriptor cameraTextureDesc = renderingData.cameraData.cameraTargetDescriptor;
        cameraTextureDesc.depthBufferBits = 1;

        int rtWidth = cameraTextureDesc.width;
        int rtHeight = cameraTextureDesc.height;

        // tempRT = new RenderTexture(rtWidth , rtHeight , 0);
        
        cmd.SetGlobalTexture(MainTexID, source);
        cmd.GetTemporaryRT(tempTexID , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear,format:RenderTextureFormat.Default);
        
        m_material.SetFloat("_BlurAmount" , 1 - volume.blurAmount.value);

        cmd.Blit(source , tempTexID , m_material , 0);
        cmd.Blit(source , tempTexID , m_material , 1);
        cmd.Blit(tempTexID , source);

        cmd.ReleaseTemporaryRT(tempTexID);
    }
}