Shader "URP/Chapter 13/EdgeDetectNormalsAndDepth"
{
    Properties
    {
        [HideInInspector] _MainTex ("", 2D) = "white"{}
    }
    SubShader
    {
        Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"}
        Pass
        {
            Name "EnemyEdgeDetect"
            Tags {"LightMode"="EnemyEdgeDetect"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // 后处理传Keyeord
            #pragma shader_feature_local_fragment _UseEdgeDetect
            #pragma shader_feature_local_fragment _UseDepthNormal
            #pragma shader_feature_local_fragment _UseDecodeDepthNormal
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                real3 positionOS : POSITION;
                real2 texcoord         : TEXCOORD0;
            };

            struct Varyings
            {
                real4 positionCS : SV_POSITION;
                real2 uv[9]      : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthNormalTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraDepthNormalDecodeTexture);SAMPLER(sampler_CameraDepthNormalDecodeTexture);
            
            CBUFFER_START(UnityPerMaterial)
                uniform real4 _MainTex_TexelSize;
                uniform real4 _EdgeColor;
                uniform real4 _BackgroundColor;
                uniform real  _EdgeOnly;
                uniform real  _SampleDistance;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(i.positionOS);
                real2 uv = i.texcoord;
                o.uv[0] = (uv + _MainTex_TexelSize.xy * real2(-2, -2) * _SampleDistance);
                o.uv[1] = (uv + _MainTex_TexelSize.xy * real2( 0, -2) * _SampleDistance);
                o.uv[2] = (uv + _MainTex_TexelSize.xy * real2( 2, -2) * _SampleDistance);
                o.uv[3] = (uv + _MainTex_TexelSize.xy * real2(-2,  0) * _SampleDistance);
                o.uv[4] = (uv + _MainTex_TexelSize.xy * real2( 0,  0) * _SampleDistance);
                o.uv[5] = (uv + _MainTex_TexelSize.xy * real2( 2,  0) * _SampleDistance);
                o.uv[6] = (uv + _MainTex_TexelSize.xy * real2(-2,  2) * _SampleDistance);
                o.uv[7] = (uv + _MainTex_TexelSize.xy * real2( 0,  2) * _SampleDistance);
                o.uv[8] = (uv + _MainTex_TexelSize.xy * real2( 2,  2) * _SampleDistance);
                return o;
            }

            real Luminance1 (real4 color)
            {
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            real Sobel (Texture2D tex, real2 uv[9])
        {
            const real Gx[9] = {-1, -2, -1,
                                 0,  0,  0,
                                 1,  2,  1};
            const real Gy[9] = {-1,  0,  1,
                                -2,  0,  2,
                                -1,  0,  1};
            real color;
            real edgeX, edgeY = 0;
            for (int i = 0; i < 9; i++)
            {
                color = Luminance1(SAMPLE_TEXTURE2D(tex, sampler_LinearClamp, uv[i]));
                edgeX += color * Gx[i];
                edgeY += color * Gy[i];
            }
            real edge = 1 - abs(edgeX) - abs(edgeY);
            return edge;
        }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, i.uv[4]);
                half4 renderMask = step(0.0001, SAMPLE_TEXTURE2D(_CameraDepthNormalTexture, sampler_LinearClamp, i.uv[4]).r);
                half4 finalColor = mainColor;
                // #if _UseEdgeDetect
                    half4 edgeDetect = Sobel(_MainTex, i.uv);
                    #if _UseDepthNormal
                        edgeDetect = Sobel(_CameraDepthNormalTexture, i.uv);
                    #endif
                half4 withEdgeColor = lerp(_EdgeColor, mainColor, edgeDetect);
                
                // 由于使用屏幕图片的贴图使用的是bilt，所以无法使用layermask去做剔除，所以这里添加了一步，利用深度法线图去生成一个遮罩
                withEdgeColor = lerp(mainColor, withEdgeColor, renderMask);
                half4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edgeDetect);
                onlyEdgeColor = lerp(_BackgroundColor, onlyEdgeColor, renderMask);
                finalColor = lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
                // #endif

                return finalColor;
            }
            ENDHLSL
        }
    }
}