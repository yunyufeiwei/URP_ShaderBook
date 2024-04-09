Shader "URP/ShaderBook/Chapter 5/FalseColor"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        [Toggle(_NORMALCOLORSHOW_ON)]_NormalColorShow("NormalColorShow",int) = 0
        [Toggle(_TANGENTCOLORSHOW)]_TangentColorShow("TangentColorShow",int) = 0
        [Toggle(_BITANGENTCOLORSHOW)]_BiTangentColorShow("BiTangentColorShow",int) = 0
        [Toggle(_UVONECOLORSHOW)]_UvOneColorShow("UvOneColorShow",int) = 0
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _NORMALCOLORSHOW_ON
            #pragma shader_feature _TANGENTCOLORSHOW
            #pragma shader_feature _BITANGENTCOLORSHOW
            #pragma shader_feature _UVONECOLORSHOW

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float4 color        : COLOR;
                float3 normalOS     :NORMAL;
                float4 tangentOS    :TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 color        : COLOR;
                
            };
           
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.color = v.color;

                //可视化法线颜色
                #if _NORMALCOLORSHOW_ON
                    o.color = half4(v.normalOS  * 0.5 + 0.5 , 1.0);
                #endif

                //可视化切线颜色
                #if _TANGENTCOLORSHOW
                    o.color = half4(v.tangentOS.xyz * 0.5 + half3(0.5,0.5,0.5) , 1.0);
                #endif

                //可视化副切线颜色
                #if _BITANGENTCOLORSHOW
                    float sign = GetOddNegativeScale() * v.tangentOS.w;
                    half3 biTangent = cross(v.normalOS,v.tangentOS.xyz) * sign;
                    o.color = half4(biTangent,1.0); 
                #endif
                
                //可视化uv颜色（第一套）
                #if _UVONECOLORSHOW
                    o.color = half4(v.texcoord.xy , 0.0,1.0);
                #endif
                
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                
                FinalColor = i.color;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
