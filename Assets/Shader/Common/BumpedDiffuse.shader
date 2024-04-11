Shader "URP/Common/Bumped Diffuse" 
{
	Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BumpMap ("NormalMap", 2D) = "bump" {}
    }

	SubShader 
	{
		Tags{ "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
		Pass 
		{
			Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct Attrubites 
			{
				float4 positionOS   : POSITION;
                float4 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
			};
			
			struct Varyings 
			{
				float4 positionHCS 	: SV_POSITION;
				float4 uv 			: TEXCOORD0;
				float4 TtoW0 		: TEXCOORD1;  
				float4 TtoW1 		: TEXCOORD2;  
				float4 TtoW2 		: TEXCOORD3;
				float3 viewDirWS	: TEXCOORD4;
			};

			TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float4 _BumpMap_ST;
            CBUFFER_END
			
			Varyings vert(Attrubites v) 
			{
				Varyings o = (Varyings)0;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
				
				o.uv.xy = v.texcoord.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
				half3 worldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);
				half3 worldTangent = TransformObjectToWorldDir(v.tangentOS.xyz);
				half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
				half3 worldBinormal = cross(worldNormal, worldTangent) * signDir; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, positionWS.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, positionWS.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, positionWS.z);  

				o.viewDirWS = GetWorldSpaceViewDir(positionWS);
				
				return o;
			}
			
			half4 frag(Varyings i) : SV_Target 
			{
				half4 FinalColor;

				Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 worldLightDir = light.direction;

				half3 positionWS = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				half3 viewDir = normalize(i.viewDirWS);
				
				half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap , sampler_BumpMap , i.uv.zw);
                half3 normalTS = UnpackNormal(normalMap).rgb;
				half3 worldNormalDir = normalize(half3(dot(i.TtoW0.xyz, normalTS), dot(i.TtoW1.xyz, normalTS), dot(i.TtoW2.xyz, normalTS)));
				
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv.xy) * _Color;
				
			 	half3 diffuse = lightColor.rgb * baseMap.rgb * max(0, dot(worldNormalDir, worldLightDir));

				FinalColor = half4(diffuse , 1.0);
				
				return FinalColor;
			}
			ENDHLSL
		}

		Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS  : SV_POSITION;       //裁剪空间的维度是四维的
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings) 0;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                //\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\Editor\ShaderGraph\Includes\Varyings.hlsl
                //获取阴影专用裁剪空间下的坐标
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                //判断是否在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                    o.positionCS = positionCS;

                return o;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
	}
}
