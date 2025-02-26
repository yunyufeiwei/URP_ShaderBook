using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class MotionBlurWithDepthTextureFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing; 
        public Shader shader;
    }

    public Settings settings = new Settings();

    MotionBlurWithDepthTexturePass m_scriptablePass;

    public override void Create()
    {
        this.name = "MotionBlurWithDepthTexture";
        m_scriptablePass = new MotionBlurWithDepthTexturePass(settings.renderPassEvent , settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_scriptablePass);
    }
}
