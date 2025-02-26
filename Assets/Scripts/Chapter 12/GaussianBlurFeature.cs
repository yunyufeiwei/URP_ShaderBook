using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class GaussianBlurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing; 
        public Shader shader;
    }
    [SerializeField]

    Settings settings = new Settings();
    GaussianBlurPass m_ScriptablePass;

    public override void Create()
    {
        this.name = "GaussianBlur";     //声明在RenderFeature上面显示的名称
        m_ScriptablePass = new GaussianBlurPass(settings.renderPassEvent , settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        //将pass加入到FrameDebug队列
        renderer.EnqueuePass(m_ScriptablePass);     
    }
}
