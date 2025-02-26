using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderEventPass = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader;
    }
    [SerializeField]
    
    Settings settings = new Settings();
    BloomPass m_ScriptablePass;

    public override void Create()
    {
        this.name = "Bloom";
        m_ScriptablePass = new BloomPass(settings.renderEventPass, settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }

}
