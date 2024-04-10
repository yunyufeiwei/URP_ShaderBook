using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RenderCubemapWizard : ScriptableWizard
{
    [Tooltip("选择一个渲染cubemap的物体位置")]
    public Transform renderFromPosition;

    [Tooltip("选择一个将环境渲染到的目标,这里的目标是一个cubemap纹理")]
    public Cubemap cubemap;

    // Update is called once per frame
    void OnWizardUpdate()
    {
        // string helpString = "select transform to render from and cubemap to render into";
        bool isValid = (renderFromPosition != null) && (cubemap != null); //判断renderFormPosition不等于空，且Cubemap也不等于空，这样就能将该位置下的环境映射到cube上
    }

    void OnWizardCreate()
    {
        GameObject go = new GameObject("CubemapCamera");
        go.AddComponent<Camera>();
        go.transform.position = renderFromPosition.position;
        go.GetComponent<Camera>().RenderToCubemap(cubemap);
        
        DestroyImmediate(go);
    }

    [MenuItem ("ArtTools/Render to cubemap")] //定义功能的使用窗口路径
    static void Rendercubemap()
    {
        ScriptableWizard.DisplayWizard<RenderCubemapWizard>("Render cubemap", "Render!");

    }
}
