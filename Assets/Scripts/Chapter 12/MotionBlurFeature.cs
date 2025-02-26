using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MotionBlurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing; 
        public Shader shader;
    }
    [SerializeField]

    Settings settings = new Settings();
    MotionBlurPass m_ScriptablePass;

    public override void Create()
    {
        this.name = "MotionBlurShow";
        m_ScriptablePass = new MotionBlurPass(settings.renderPassEvent , settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);     
    }
}
