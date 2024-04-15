using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;     //设置渲染事件执行位置，在后处理之前
        public Shader shader;

        //public Color Feature_EdgeColor = Color.black;   //使用后处理面板调参
    }
    
    [SerializeField] public Settings settings = new Settings();     //开放设置，定义的class类需要再外部重新new出来，否则调用不到
    private EdgeDetectionPass m_ScriptablePass;
    
    public override void Create()
    {
        this.name = "EdgeDetection";        //这里定义的name是在RenderFeature上面显示的名字，并不是FrameDebug面板的事件名称
        m_ScriptablePass = new EdgeDetectionPass(settings.RenderPassEvent, settings.shader);  //初始化渲染事件

        // m_ScriptablePass.pass_EdgeColor = settings.Feature_EdgeColor;    //使用后处理面板调参
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);     //将该pass添加到渲染队列
    }
}
