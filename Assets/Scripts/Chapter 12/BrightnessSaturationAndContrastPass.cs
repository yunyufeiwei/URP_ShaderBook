using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BrightnessSaturationAndContrastPass : ScriptableRenderPass
{
    private static readonly string Tag = "CustomRenderPassEvent";   //定义一个静态的字符创名称，用在FrameDebug的渲染事件中
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //设置渲染的主纹理
    private static readonly int tempTexID = Shader.PropertyToID("_TempTexture");    //定义临时的存储的RT纹理   
    
    Material m_material;    //定义材质
    private BrightnessSaturationAndContrastVolume volume;   //定义一个Volume传递的接口

    RenderTargetIdentifier source;  //定义当前相机的图像
    
    public BrightnessSaturationAndContrastPass(RenderPassEvent renderEvent, Shader m_shader)
    {
        renderPassEvent = renderEvent;  //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;          //传入shader
        m_material = CoreUtils.CreateEngineMaterial(m_shader);      //通过指定的shader创建材质
        
        
    }
    //执行
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

        var stack = VolumeManager.instance.stack;        //实例化volume到堆栈
        volume = stack.GetComponent<BrightnessSaturationAndContrastVolume>();   //获取Volume上的组件上添加的脚本
        if (volume == null)
        {
            Debug.LogError("Volume组件获取失败！");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(Tag);     //定义在FrameDebug里面渲染事件位置的名称
        OnRenderImage(cmd,renderingData);
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);

    }

    public void OnRenderImage(CommandBuffer cmd, RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = tempDescriptor.width;
        int rtHeight = tempDescriptor.height;
        
        cmd.SetGlobalTexture(MainTexID,source);
        cmd.GetTemporaryRT(tempTexID,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);
        
        m_material.SetFloat("_Brightness",volume.brightness.value);
        m_material.SetFloat("_Saturation",volume.saturation.value);
        m_material.SetFloat("_Contrast",volume.contrast.value);
        
        cmd.Blit(source,tempTexID,m_material);      //将从相机获取到的图像通过材质shader里面的计算，传递到定义的临时RT贴图
        cmd.Blit(tempTexID,source);
        
        cmd.ReleaseTemporaryRT(tempTexID);      //将计算完成之后释放申请的临时RT
    }
}
