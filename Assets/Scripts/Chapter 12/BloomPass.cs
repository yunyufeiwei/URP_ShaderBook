using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomPass : ScriptableRenderPass
{
    static readonly string Tag = "CustomRenderPassEvent";
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");
    static readonly int tempTexID_01 = Shader.PropertyToID("_TempTexture_01");
    static readonly int tempTexID_02 = Shader.PropertyToID("_TempTexture_02");

    Material m_material;
    BloomVolume volume;

    RenderTargetIdentifier source;

    public BloomPass(RenderPassEvent evt, Shader m_shader)
    {
        renderPassEvent = evt;
        var shader = m_shader;
        if (shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (m_material == null)
        {
            UnityEngine.Debug.LogError("材质没找到！");
            return;
        }
        if (!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
            return;
        }

        var stack = VolumeManager.instance.stack;
        volume = stack.GetComponent<BloomVolume>();
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(Tag);

        OnRenderImage(cmd, ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    void OnRenderImage(CommandBuffer cmd, ref RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        
        //Volume数据，定义从Volume脚本上拿到的参数
        int m_Iterations = volume.interations.value;                    //定义迭代的次数
        float m_BlurSpread = volume.bulrSize.value;                    //定义模糊的方位
        int m_DownSample = volume.downSample.value;                      //定义降采样的次数
        float m_LuminanceThreshold = volume.LuminanceThreshold.value;    //定义Bloom的阈值

        RenderTextureDescriptor inRTDesc = renderingData.cameraData.cameraTargetDescriptor;
        inRTDesc.depthBufferBits = 0;

        int rtWidth = inRTDesc.width / m_DownSample;
        int rtHeight = inRTDesc.height / m_DownSample;

        cmd.SetGlobalTexture(MainTexID, source);
        cmd.GetTemporaryRT(tempTexID_01, rtWidth, rtHeight, depthBuffer: 0, FilterMode.Trilinear, format: RenderTextureFormat.Default);
        cmd.GetTemporaryRT(tempTexID_02, rtWidth, rtHeight, depthBuffer: 0, FilterMode.Trilinear, format: RenderTextureFormat.Default);

        m_material.SetFloat("_LuminanceThreshold", m_LuminanceThreshold);
        
        cmd.Blit(source, tempTexID_01, m_material, 0);

        for (int i = 0; i < m_Iterations; i++)
        {
            m_material.SetFloat("_blurSize", 1.0f + i * m_BlurSpread);

            cmd.Blit(tempTexID_01, tempTexID_02, m_material, 1);
            cmd.Blit(tempTexID_02, tempTexID_01, m_material, 2);
        }

        cmd.SetGlobalTexture("_BloomTex", tempTexID_01);
        cmd.Blit(source, tempTexID_02, m_material, 3);
        cmd.Blit(tempTexID_02, source);

        cmd.ReleaseTemporaryRT(tempTexID_01);
        cmd.ReleaseTemporaryRT(tempTexID_02);
    }
}


