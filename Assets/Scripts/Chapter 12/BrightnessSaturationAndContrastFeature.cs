using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class BrightnessSaturationAndContrastFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;     //设置渲染事件执行位置，在后处理之前
        public Shader shader;
    }

    [SerializeField] public Settings settings = new Settings();     //开放设置，定义的class类需要再外部重新new出来，否则调用不到
    private BrightnessSaturationAndContrastPass m_ScriptablePass;   //基于Pass脚本里面的方法，声明一个变量来调用该类下的  
    
    public override void Create()
    {
        this.name = "BrightnessSaturationAndContrastFeature";        //这里定义的name是在RenderFeature上面显示的名字，并不是FrameDebug面板的事件名称
        m_ScriptablePass = new BrightnessSaturationAndContrastPass(settings.RenderPassEvent, settings.shader);  //初始化渲染事件
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);     //汇入队列
    }
}
