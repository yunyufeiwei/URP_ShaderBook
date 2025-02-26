using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectNormalsAndDepthFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public RenderPassEvent RenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        public Shader shader = null;
    }
    
    public Settings settings = new Settings();          //将类进行实例化，显示在RenderFeature的面板上
    EdgeDetectNormalsAndDepthPass enemyEdgeDetectPass;
    
    public override void Create()
    {
        enemyEdgeDetectPass = new EdgeDetectNormalsAndDepthPass(settings);
    }
    
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(enemyEdgeDetectPass);
    }
}