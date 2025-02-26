//参考网址：
//https://zhuanlan.zhihu.com/p/591579499?utm_id=0

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GaussianBlurPass : ScriptableRenderPass
{
    #region  变量声明
    static readonly string RenderEventPassName = "CustomRenderPassEvent";                                    //新建渲染事件的名称
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");
    static readonly int tempTexID_01 = Shader.PropertyToID("TempGaussianBlurTexture_01");           //声明临时的RT纹理，这里的字符串名称就是在FrameDebugger里面Detail里面的名称
    static readonly int tempTexID_02 = Shader.PropertyToID("TempGaussianBlurTexture_02");

    GaussianBlurVolume volume;              //新建Volume组件
    Material m_material;                           //新建材质
    RenderTargetIdentifier source;                //设置当前渲染目标
    #endregion

    public GaussianBlurPass(RenderPassEvent renderEvent , Shader m_shader)
    {
        renderPassEvent = renderEvent;      //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;    //通过shader创建材质，便于后面通过材质参数进行计算
        if(shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);
    }

    //渲染执行
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(m_material == null)
        {
            Debug.LogError("材质初始化创建失败!");
            return;
        }
        if(!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
            return;
        }

        //Volume相关
        var stack = VolumeManager.instance.stack;
        volume = stack.GetComponent<GaussianBlurVolume>();
        if(volume == null)
        {
            Debug.LogError("Volume组件获取失败!");
            return;
        }
        
        CommandBuffer cmd = CommandBufferPool.Get(RenderEventPassName);      //拿到在FrameDebug里面渲染事件相关信息

        OnRenderImage(cmd , ref renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    void OnRenderImage(CommandBuffer cmd , ref RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;     //获取当前相机的纹理

        //Volume数据，定义从Volume脚本上拿到的参数
        int interations = volume.interations.value;     //定义迭代的次数
        int downSample = volume.downSample.value;       //降采样比例，当前相机宽高比，除以了该值得到采样的实际画面宽高  

        //申请临时RT，并定义宽度与高度
        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = tempDescriptor.width / downSample;
        int rtHeight = tempDescriptor.height / downSample;

        m_material.SetFloat("_blurSize",volume.blurSize.value);

        cmd.SetGlobalTexture(MainTexID , source);
        cmd.GetTemporaryRT(tempTexID_01 , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);
        cmd.GetTemporaryRT(tempTexID_02 , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);
        
        if(interations > 0)
        {
            //迭代前，把源图像sourceTex缩放计算后存储到定义的第一个缓存buffer0中。
            cmd.Blit(source , tempTexID_01);
            for(int i = 0 ; i < interations ; i++)
            {
                //利用两个临时缓存在迭代之间进行交替。
                //把迭代前输出的buffer0图像，输出到定义的第二个缓存buffer1中，以此往返迭代次数
                cmd.Blit(tempTexID_01 , tempTexID_02 , m_material , 0);
                cmd.Blit(tempTexID_02 , tempTexID_01 , m_material , 1);
            }
            cmd.Blit(tempTexID_01 , source);
        }
        //释放申请的临时RT
        cmd.ReleaseTemporaryRT(tempTexID_01);
        cmd.ReleaseTemporaryRT(tempTexID_02);
    }
}


