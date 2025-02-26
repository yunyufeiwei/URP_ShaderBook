#region 相关代码类型的说明
//参考链接：
//https://zhuanlan.zhihu.com/p/348978998
//https://zhuanlan.zhihu.com/p/591579499
//https://blog.csdn.net/mango9126/article/details/126418331

//---------------------------------------------------------------------------------------------------------------
//|RenderTargetIdentifier;       //用于具体ScriptableRenderPass配置指定渲染目标
//|RTHandle;                     //主要目的是维护渲染目标的句柄(句柄是一个用来表示对象或者项目的标识符),实际使用其RenderTargetIdentifier()方法获取rtid，
//|Packages/com.unity.render-pipelines.universal@10.9.0/Runtime/RenderTargetHandle.cs
//|(private RenderTargetIdentifier rtid { set; get; })
//|
//|RenderTextureDescriptor;      //创建临时RT，指定格式
//|RenderTexture;
//|Shader.PropertyToID();       //1.把渲染目标的结果用在贴图给shader使用。2.RTHandle先初始化Shader.PropertyID()
//|Blit指令以源RenderTarget渲染到目标RenderTarget,即(source，destination)
//|
//|TemporaryRT vs RenderTarget 区别
//|1.RenderTarget是GPU渲染时的渲染目标，不一定可以写到内存。
//|2.TemporaryRT是贴图，可以作为GPU渲染时的渲染目标，可以写回到内存，也可以读回到渲染目标
//---------------------------------------------------------------------------------------------------------------

//接口说明更新
//---------------------------------------------------------------------------------------------------------------
//|RenderTargetIdentifier                                                                                              
//|  ---Unity CoreModule实现，定义CommandBuffer用到的RendertTexute
//|  ---封装了texture的创建，因为texture创建方式有几种，rt，texture，BuiltinRenderTexture ，GetTemporaryRT
//|  ---这个类定义了rt的各种属性，真正创建应该是在CommandBuffer内部
//|  ---CommandBuffer.SetRenderTarget，可分别设置color和depth，以及贴图处理方式
//|  ---CommandBuffer.SetGlobalTexture,效果是吧texture赋值给shader变量，shader变量采样这个texture
//|RenderTargetHandle
//|  ---UPR对RenderTargetIdentifier的一个封装
//|  ---保存shader变量的id，提升性能，避免多级hash计算
//|  ---真正用rt的时候，才会创建RenderTargetIdentifier
//|  ---定义了一个静态的CameraTarget
//|RenderTextureDescriptor ---封装创建RT需要的所有信息，可复用，修改部分值，减少创建消耗
//---------------------------------------------------------------------------------------------------------------
#endregion


using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

//渲染逻辑的核心pass
class BrightnessSaturationAndContrastPass : ScriptableRenderPass
{
    static readonly string Tag = "CustomRenderPassEvent";       //定义一个静态的字符创名称，用在FrameDebug的渲染事件中
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");                    //设置渲染的主纹理
    static readonly int tempTexID = Shader.PropertyToID("_TempTexture");                //定义临时的存储的RT纹理   

    Material m_material;                                       //定义材质
    BrightnessSaturationAndContrastVolume volume;        //定义一个Volume传递的接口
    
    RenderTargetIdentifier source;                                                      //定义当前相机的图像
    // RenderTexture RtTexture; 
    
    public BrightnessSaturationAndContrastPass(RenderPassEvent renderEvent , Shader m_shader)
    {
        renderPassEvent = renderEvent;                                                  //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;                                                          //传入shader
        if(shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);                 //通过指定的shader创建材质
    }                                   

    //Execute执行
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(m_material == null)
        {
            Debug.LogError("材质初始化失败！");
        }
        if(!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理位未激活！");
            return;
        }

        var stack = VolumeManager.instance.stack;       //实例化volume到堆栈
        volume = stack.GetComponent<BrightnessSaturationAndContrastVolume>();    //获取Volume上的组件上添加的脚本
        if(volume == null)
        {
            Debug.LogError("Volumen组件获取失败!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(Tag);          //定义在FrameDebug里面渲染事件位置的名称
        OnRenderImage(cmd , renderingData);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public void OnRenderImage(CommandBuffer cmd , RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;     //
        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = tempDescriptor.width;
        int rtHeight = tempDescriptor.height;

        cmd.SetGlobalTexture(MainTexID , source);
        cmd.GetTemporaryRT(tempTexID , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);

        //将volume里面的值传递到shader对应的属性
        m_material.SetFloat("_Brightness" , volume.brightness.value); 
        m_material.SetFloat("_Saturation" , volume.saturation.value);
        m_material.SetFloat("_Contrast"   , volume.contrast.value);
        
        cmd.Blit(source , tempTexID , m_material);           //将从相机获取到的图像通过材质shader里面的计算，传递到定义的临时RT贴图
        cmd.Blit(tempTexID,source);       
        
        cmd.ReleaseTemporaryRT(tempTexID); //将计算完成之后释放申请的临时RT
    }
}
