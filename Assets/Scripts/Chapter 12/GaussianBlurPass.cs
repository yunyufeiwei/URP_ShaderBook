using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GaussianBlurPass : ScriptableRenderPass
{
    private static readonly string Tag = "GaussianBlur";
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //设置渲染的主纹理
    private static readonly int tempTexID_01 = Shader.PropertyToID("_TempGaussianBlurTexture_01");    //定义临时的存储的RT纹理  
    private static readonly int tempTexID_02 = Shader.PropertyToID("_TempGaussianBlurTexture_02");
    
    private Material m_material;
    private GaussianBlurVolume volume;
    
    private RenderTargetIdentifier source;
    
    public GaussianBlurPass(RenderPassEvent renderEvent, Shader m_shader)
    {
        renderPassEvent = renderEvent;  //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;          //传入shader
        if(shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);      //通过指定的shader创建材质
    }
    
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (m_material == null)
        {
            Debug.LogError("材质初始化失败！");
        }

        if (!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
        }
        
        //Volume相关
        var stack = VolumeManager.instance.stack;        //实例化volume到堆栈
        volume = stack.GetComponent<GaussianBlurVolume>();   //获取Volume上的组件上添加的脚本
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败！");
            return;
        }
        
        CommandBuffer cmd = CommandBufferPool.Get(Tag);     //定义在FrameDebug里面渲染事件位置的名称
        OnRenderImage(cmd,renderingData);
        
        //上下文加入buffer
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public void OnRenderImage(CommandBuffer cmd, RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle; //获取当前相机的纹理

        //Volume数据，定义从Volume脚本上拿到的参数
        int interations = volume.interations.value;
        int downSample = volume.downSample.value;
        
        //申请临时RT，并定义宽度与高度
        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = tempDescriptor.width/downSample;     //定义临时RT的宽度
        int rtHeight = tempDescriptor.height/downSample;   //定义临时RT的高度
        
        m_material.SetFloat("_BlurSize",volume.blurSize.value);
        
        cmd.SetGlobalTexture(MainTexID,source);
        cmd.GetTemporaryRT(tempTexID_01,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);
        cmd.GetTemporaryRT(tempTexID_02,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);

        if (interations > 0)
        {
            //迭代前，把源图像sourceTex缩放计算后存储到定义的第一个缓存buffer0中。
            cmd.Blit(source,tempTexID_01);
            for (int i = 0; i < interations; i++)
            {
                //利用两个临时缓存在迭代之间进行交替。
                //把迭代前输出的buffer0图像，输出到定义的第二个缓存buffer1中，以此往返迭代次数
                cmd.Blit(tempTexID_01,tempTexID_02,m_material,0);
                cmd.Blit(tempTexID_02,tempTexID_01,m_material,1);
            }
            cmd.Blit(tempTexID_01,source);
        }
        //释放申请的临时RT
        cmd.ReleaseTemporaryRT(tempTexID_01);
        cmd.ReleaseTemporaryRT(tempTexID_02);
    }
}
