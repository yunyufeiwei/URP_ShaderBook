Shader "URP/Common/Bumped Specular" 
{
	Properties 
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_BaseMap ("BaseMap", 2D) = "white" {}
		_BumpMap ("NormalMap", 2D) = "bump" {}
		_SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
		[PowerSolid(50)]_SpecularPower ("SpecularPower", Range(8.0, 256)) = 20
	}

	SubShader 
	{
		Tags{ "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
		
		Pass 
		{ 
			Tags { "LightMode"="ForwardBase" }
		
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
				float4 _SpecularColor;
				float  _SpecularPower;
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
				
			 	half3 diffuse = lightColor.rgb * baseMap.rgb * max(0, dot(worldNormalDir, worldLightDir) * 0.5 + 0.5);

				half3 halfDir = normalize(worldLightDir + viewDir);
			 	half3 specular = lightColor * _SpecularColor.rgb * pow(max(0, dot(worldNormalDir, halfDir)), _SpecularPower);

				FinalColor = half4(diffuse + specular , 1.0);
				
				return FinalColor;
			}
			ENDHLSL
		}
	} 
}
