using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionPass : ScriptableRenderPass
{
    private static readonly string Tag = "EdgeDetectionPass";                            //定义一个静态的字符创名称，用在FrameDebug的渲染事件中
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");        //设置渲染的主纹理
    private static readonly int tempTexID = Shader.PropertyToID("_TempTexture");    //定义临时的存储的RT纹理  
    
    private Material m_material;
    EdgeDetectionVolume volume;
    // public Color pass_EdgeColor;
    
    RenderTargetIdentifier source;  //定义当前相机的图像
    
    //Pass初始化,设置渲染事件，判断调用shader，创建材质
    public EdgeDetectionPass(RenderPassEvent renderEvent, Shader m_shader)
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
        
        var stack = VolumeManager.instance.stack;        //实例化volume到堆栈
        volume = stack.GetComponent<EdgeDetectionVolume>();   //获取Volume上的组件上添加的脚本
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
        source = renderingData.cameraData.renderer.cameraColorTargetHandle; //当前相机rt
        
        //临时RT
        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = tempDescriptor.width;     //定义临时RT的宽度
        int rtHeight = tempDescriptor.height;   //定义临时RT的高度
        
        cmd.SetGlobalTexture(MainTexID,source);
        cmd.GetTemporaryRT(tempTexID,rtWidth,rtHeight,depthBuffer:0,FilterMode.Trilinear,format:RenderTextureFormat.Default);
        
        //材质参数传递
        // m_material.SetColor("_EdgeColor" , pass_EdgeColor);      //使用后处理面板调参
        m_material.SetFloat("_EdgeOnly",volume.edgeOnly.value);
        m_material.SetColor("_EdgeColor" , volume.edgeColor.value);
        m_material.SetColor("_BackgroundColor",volume.backGroundColor.value);
        
        cmd.Blit(source,tempTexID,m_material);      //将从相机获取到的图像通过材质shader里面的计算，传递到定义的临时RT贴图
        cmd.Blit(tempTexID,source);
        
        cmd.ReleaseTemporaryRT(tempTexID);      //将计算完成之后释放申请的临时RT
        
    }
}
