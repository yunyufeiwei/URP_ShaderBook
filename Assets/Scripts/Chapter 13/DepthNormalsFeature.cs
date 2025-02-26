using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthNormalsFeature : ScriptableRendererFeature
{
    [SerializeField] private RenderPassEvent Event = RenderPassEvent.AfterRenderingPrePasses;   //声明PassEvent(渲染事件)在FrameDebug中的插入时机
    [SerializeField] private Shader shader = null;      //声明可序列化的Shader变量
    [SerializeField] public Filters _filters;          //序列化DepthNormalSettings类在面板上
    private DepthNormalsPass m_DepthNormalsPass;        //实例化DepthNormalPass类   

    public static RenderQueueRange GetQueueRange(Filters.RenderQueueType queue)
    {
        switch(queue) 
        {
            case Filters.RenderQueueType.All:
                return RenderQueueRange.all;
            case Filters.RenderQueueType.Opaque:
                return RenderQueueRange.opaque;
            case Filters.RenderQueueType.Transparent: 
                return RenderQueueRange.transparent;
            default: 
                return RenderQueueRange.opaque;
        } 
    }

    public override void Create()
    {
        //如果shader未指定，则直接返回。
        if(shader == null) return;
        
        //实例化DepthNormalPass类，并将Feature中的属性传入到Pass
        m_DepthNormalsPass = new DepthNormalsPass(Event , shader , _filters);
    }
    
    //将Pass添加到渲染列表
    public override void AddRenderPasses(ScriptableRenderer renderer , ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            //将m_DepthNormalsPass这个Pass添加的渲染队列
            renderer.EnqueuePass(m_DepthNormalsPass);
        }
    }
}

//定义面板上的属性，并添加序列化标签，这样能让类里面声明的Public属性序列化
[Serializable]
public class Filters
{
    public enum RenderQueueType{All , Opaque , Transparent};
    public RenderQueueType queue = RenderQueueType.Opaque;
    public LayerMask layerMask = -1;
}

