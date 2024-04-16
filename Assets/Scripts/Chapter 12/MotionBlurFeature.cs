using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class MotionBlurFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
    }

    [SerializeField] private Settings settings = new Settings();
    private MotionBlurPass m_ScriptablePass;
    
    public override void Create()
    {
        this.name = "MotionBlurPass";     //声明在RenderFeature上面显示的名称
        m_ScriptablePass = new MotionBlurPass(settings.renderPassEvent, settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //将pass加入到FrameDebug队列
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
