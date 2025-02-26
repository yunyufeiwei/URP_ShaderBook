Shader "URP/Chapte 12/Chapter 12/EdgeDetection"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"  }
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}  
            Cull off 
            ZTest always 
            ZWrite Off
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
                float3 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : POSITION;
                float2 uv[9]        : TEXCOORD0;
               
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4  _MainTex_TexelSize;
                half  _EdgeOnly;
                half4 _EdgeColor;
                half4 _BackgroundColor;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                half2 uv = v.texcoord;

                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
              
                return o;
            }

            //亮度的计算公式，这里封装成方法
            half luminance(half4 color) 
            {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}

            half Sobel(Varyings i) 
            {
				const half Gx[9] = {-1,  0,  1,
                                    -2,  0,  2,
                                    -1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
                                    0,  0,  0,
                                    1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) 
                {
					texColor = luminance(SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
				half edge = 1 - abs(edgeX) - abs(edgeY);
				
				return edge;
			}

            //片段着色器
            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half edge = Sobel(i);
				
				half4 withEdgeColor = lerp(_EdgeColor, SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv[4]), edge);
				half4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
                
                FinalColor = lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);

				return FinalColor;
            }
            ENDHLSL
        }
    }
}
