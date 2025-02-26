Shader "URP/Chapter 5/FalseColor"
{
    Properties
    {
        [Toggle(_NORMALCOLORSHOW_ON)]_NormalColorShow("NormalColorShow",int) = 0
        [Toggle(_TANGENTCOLORSHOW_ON)]_TangentColorShow("TangentColorShow",int) = 0
        [Toggle(_BITANGENTCOLORSHOW_ON)]_BiTangentColorShow("BiTangentColorShow",int) = 0
        [Toggle(_UVONECOLORSHOW_ON)]_UvOneColorShow("UvOneColorShow",int) = 0
        [Toggle(_UVTWOCOLORSHOW_ON)]_UvTwoColorShow("UvTwoColorShow",int) = 0
        [Toggle(_UVONEFRACCOLORSHOW_ON)]_UvOneFracColorShow("UvOneFracColorShow",int) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry" }
        LOD 100
        ZWrite On
        
        Pass
        {
            Tags{"LihgtMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _VERTEXCOLORSHOW_ON
            #pragma shader_feature _NORMALCOLORSHOW_ON
            #pragma shader_feature _TANGENTCOLORSHOW_ON
            #pragma shader_feature _BITANGENTCOLORSHOW_ON
            #pragma shader_feature _UVONECOLORSHOW_ON
            #pragma shader_feature _UVTWOCOLORSHOW_ON
            #pragma shader_feature _UVONEFRACCOLORSHOW_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 color        : COLOR;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS      : SV_POSITION;
                float4 color            : COLOR;
                float2 uv               : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                

                o.color = v.color;

                //可视化法线颜色
                #if _NORMALCOLORSHOW_ON
                    o.color = half4(v.normalOS * 0.5 + 0.5 ,1.0);
                #endif

                //可视化切线颜色
                #if _TANGENTCOLORSHOW_ON
                    o.color = half4(v.tangentOS.xyz * 0.5 + half3(0.5,0.5,0.5) , 1.0);
                #endif

                //可视化副切线颜色
                #if _BITANGENTCOLORSHOW_ON
                    float sign = GetOddNegativeScale() * v.tangentOS.w;
                    half3 biTangent = cross(v.normalOS , v.tangentOS.xyz) * sign;
                    o.color = half4(biTangent , 1.0);
                #endif

                //可视化第一套纹理坐标
                #if _UVONECOLORSHOW_ON
                    o.color = half4(v.texcoord.xy , 0.0 , 1.0);
                #endif

                //可视化第二套纹理坐标
                #if _UVTWOCOLORSHOW_ON
                    o.color = half4(v.texcoord.xy,0.0,1.0);
                #endif

                //可视化第一组纹理布坐标小数
                #if _UVONEFRACCOLORSHOW_ON
                    o.color.rg = frac(v.texcoord);
                    //return any(x)如果x参的任何组件为非零，则为True，否则为false
                    if(any(saturate(v.texcoord) - v.texcoord))
                    {
                        o.color.b = 0.5;
                    }
                    o.color.a = 1;
                #endif


                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                FinalColor = i.color;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
