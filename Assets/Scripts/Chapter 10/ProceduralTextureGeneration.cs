using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//让该脚本在编辑器模式下运行
[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour
{
    public Material material = null;

    #region Material properties
    //声明纹理的大小   SetProperty使用了一个开源插件
    [SerializeField , SetProperty("textureWidth")]
    private int m_textureWidth = 512; 
    public int textureWidth
    {
        get
        {
            return m_textureWidth;
        }
        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }

    //声明纹理的背景颜色
    [SerializeField ,SetProperty("backgroundColor")]
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }
    

    //声圆点颜色
    [SerializeField , SetProperty("circleColor")]
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get
        {
            return m_circleColor;        
        }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }

    //声明模糊因子
    [SerializeField , SetProperty("blurFactor")]
    private float m_blurFactor = 2.0f;
    public float blurFactor
    {
        get
        {
            return m_blurFactor;
        }
        set
        {
            m_blurFactor = value;
            _UpdateMaterial();
        }
    }
    #endregion

    #region 属性生成传递
    //保存生成的程序纹理  声明一个Texture2D类型的纹理变量
    private Texture2D m_generatedTexture = null;

    void Start() 
    {
        if(material == null)
        {
            //首先判断材质是否为空，如果是空的话，则将打印log并实例化材质
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if(renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer.");
                return;
            }
            material = renderer.sharedMaterial;
        }
        _UpdateMaterial();
    }

    private void _UpdateMaterial()
    {
        //检查materials变量是否为空
        if(material != null)
        {
            //如果材质不为空，则将程序化生成的纹理赋值给m_generatedTexture
            m_generatedTexture = _GenerateProceduralTexture();
            //将上一步赋值之后的m_generatedTexture传递到shader中的_BaseMap属性
			material.SetTexture("_BaseMap", m_generatedTexture);
        }
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor) 
    {
		Color mixColor = Color.white;
		mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
		mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
		mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
		mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
		return mixColor;
	}

    private Texture2D _GenerateProceduralTexture()
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth , textureWidth);

        //定义圆与圆之间的距离
        float circleInterval = textureWidth/4.0f;
        //定义圆的半径
        float radius = textureWidth / 10.0f;
        //定义模糊系数
        float edgeBlur = 1.0f / blurFactor;

        for(int w = 0 ; w<textureWidth; w++)
        {
            for(int h = 0 ; h<textureWidth;h++)
            {
                //使用背景颜色进行初始化
                Color pixel = backgroundColor;

                //依次画9个圆
                for(int i = 0;i<3;i++)
                {
                    for (int j = 0; j < 3; j++) 
                    {
                        //计算当前所绘制的圆的圆心位置
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));
                        //计算当前像素与圆心的距离
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;
                        //模糊圆的边界
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));
                        //与之前得到的颜色进行混合
                        pixel = _MixColor(pixel, color, color.a);
                    }                    
                }
                proceduralTexture.SetPixel(w, h, pixel);
            }
        }
        proceduralTexture.Apply();

		return proceduralTexture;
    }
    #endregion
    
}