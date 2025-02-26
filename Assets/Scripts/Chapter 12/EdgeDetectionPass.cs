using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionPass : ScriptableRenderPass
{
    #region  设置变量
    static readonly string RenderEventPassName = "CustomRenderPassEvent";                       //定义一个静态的字符创名称，用于显示在FrameDebug的渲染事件中
    static readonly int MainTexID = Shader.PropertyToID("_MainTex");                    //shader的_MainTex变量，作为主纹理贴图给ID
    static readonly int tempTexID = Shader.PropertyToID("_TempEdgeDetectionRT");         //声明临时贴图的ID

    Material m_material;                            //新建材质接口
    EdgeDetectionVolume volume;                     //新建Volume接口
    
    RenderTargetIdentifier source;                  //定义当前相机目标
    #endregion

    //Pass初始化，设置渲染事件、判断调用的shader、创建材质
    public EdgeDetectionPass(RenderPassEvent renderEvent , Shader m_shader)
    {
        renderPassEvent = renderEvent;      //设置渲染事件位置，这里的renderPassEvent是从ScriptableRenderPass里面得到的
        var shader = m_shader;              //通过shader创建材质，便于后面通过材质参数进行计算
        if(shader == null){return;}
        m_material = CoreUtils.CreateEngineMaterial(m_shader);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(m_material == null)
        {
            Debug.LogError("材质初始化创建失败!");
        }
        if(!renderingData.cameraData.postProcessEnabled)
        {
            Debug.LogError("相机的后处理未激活！");
            return;
        }

        var stack = VolumeManager.instance.stack;              //Volume相关，创建堆栈，
        volume = stack.GetComponent<EdgeDetectionVolume>();    //从堆栈中获取到相应的Volume组件
        if(volume == null)
        {
            Debug.LogError("Volume组件获取失败!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(RenderEventPassName);                 //实现在FrameDebug里面渲染事件的位置

        OnReadImage(cmd , ref renderingData);
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    //ref作用是函数内部参数改变，对应外部参数也跟着改变
    void OnReadImage(CommandBuffer cmd , ref RenderingData renderingData)   
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;       //当前相机

        RenderTextureDescriptor tempDescriptor = renderingData.cameraData.cameraTargetDescriptor;   //声明临时RT
        int rtWidth = tempDescriptor.width;         //定义临时RT的宽度
        int rtHeight = tempDescriptor.height;       //定义临时RT的高度

        //将Volume里面的值传递到shader里面对应的属性
        m_material.SetFloat("_EdgeOnly" , volume.edgeOnly.value);
        m_material.SetColor("_EdgeColor" , volume.edgeColor.value);
        m_material.SetColor("_BackgroundColor" , volume.backGroundColor.value);

        cmd.SetGlobalTexture(MainTexID, source);                 //给MainTexID赋值，将source的渲染结果传递给材质
        cmd.GetTemporaryRT(tempTexID , rtWidth , rtHeight , depthBuffer:0 , FilterMode.Trilinear , format:RenderTextureFormat.Default);
        
        //开始绘制计算
        cmd.Blit(source , tempTexID , m_material);
        cmd.Blit(tempTexID , source);

        cmd.ReleaseTemporaryRT(tempTexID); //将计算完成之后释放申请的临时RT
    }
}
