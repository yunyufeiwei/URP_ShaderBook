using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class BloomFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
    }

    [SerializeField] private Settings settings = new Settings();
    private BloomPass m_ScriptablePass;
    
    public override void Create()
    {
        this.name = "Bloom";     //声明在RenderFeature上面显示的名称
        m_ScriptablePass = new BloomPass(settings.renderPassEvent, settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //将pass加入到FrameDebug队列
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
