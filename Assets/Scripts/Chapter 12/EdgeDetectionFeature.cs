using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using UnityEngine;
using UnityEngine.Rendering.Universal;
// using System;

public class EdgeDetectionFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;         //设置渲染事件执行位置，在后处理之前
        public Shader shader;                                                                           //设置shader
    }
    [SerializeField]
    Settings settings = new Settings();                     //class类里面定义的方法，需要再外面在创建出来
    
    EdgeDetectionPass m_ScriptablePass;                     //声明EdgeDetection脚本，定义渲染Pass

    public override void Create()
    {
        this.name = "EdgeDetection";                        //这里定义的name是在RenderFeature上面显示的名字，并不是FrameDebug面板的事件名称
        m_ScriptablePass = new EdgeDetectionPass(settings.renderPassEvent , settings.shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);     //将该Pass添加到渲染队列中
    }
}
