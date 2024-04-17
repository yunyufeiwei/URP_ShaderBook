using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class FogWithNoiseFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
    }

    [SerializeField] private Settings settings = new Settings();
    FogWithNoisePass m_ScriptablePass;
    
    public override void Create()
    {
        this.name = "FogWithNoise";     //声明在RenderFeature上面显示的名称
        m_ScriptablePass = new FogWithNoisePass(settings.renderPassEvent, settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //将pass加入到FrameDebug队列
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
