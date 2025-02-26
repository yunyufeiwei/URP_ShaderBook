Shader "URP/Chapte 11/ScrollingBackground"
{
    Properties
    {
        _BackLayer ("BackLayer(RGB)", 2D) = "white" {}
		_FrontLayer ("FrontLayer(RGB)", 2D) = "white" {}
		_ScrollX ("BackLayerSpeed", Float) = 1.0
		_Scroll2X ("FrontLayerSpeed", Float) = 1.0
		_Multiplier ("Layer Multiplier", Float) = 1
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"}

        Pass
        {
			Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

           struct Attributes 
			{
				float4 positionOS 	: POSITION;
				float4 texcoord 	: TEXCOORD0;
			};

           struct Varyings 
		    {
				float4 positionHCS 	: SV_POSITION;
				float4 uv 			: TEXCOORD0;
			};

			TEXTURE2D(_BackLayer);SAMPLER(sampler_BackLayer);
			TEXTURE2D(_FrontLayer);SAMPLER(sampler_FrontLayer);

			CBUFFER_START(UnityPerMaterial)
				float4 _BackLayer_ST;
				float4 _FrontLayer_ST;
				float  _ScrollX;
				float  _Scroll2X;
				float  _Multiplier;
			CBUFFER_END

			Varyings vert (Attributes v) 
			{
				Varyings o = (Varyings)0;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _BackLayer) + frac(float2(_ScrollX, 0.0) * _Time.y); 	//使用uv寄存器的前两个通道存储第一套纹理
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _FrontLayer) + frac(float2(_Scroll2X, 0.0) * _Time.y);  //使用uv寄存器的后两个通道存储第二套纹理
				
				return o;
			}

           half4 frag (Varyings i) : SV_Target 
		   {
		   		half4 FinalColor;

				half4 firstLayer = SAMPLE_TEXTURE2D(_BackLayer , sampler_BackLayer , i.uv.xy);
				half4 secondLayer = SAMPLE_TEXTURE2D(_FrontLayer , sampler_FrontLayer , i.uv.zw);
				
				half4 c = lerp(firstLayer, secondLayer, secondLayer.a);//使用前景图片的Alpha通道作为遮罩图，即白色的地方显示第一个参数贴图，黑色地方显示第二个参数贴图
				FinalColor = half4(c.rgb * _Multiplier , 1.0);
				
				return FinalColor;
			}
            ENDHLSL
        }
    }
}
