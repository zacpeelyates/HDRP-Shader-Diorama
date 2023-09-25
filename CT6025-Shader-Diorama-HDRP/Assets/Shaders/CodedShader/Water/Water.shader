Shader "Unlit/Water"
{
   	Properties
	{

		_MainTex ("Main Texture", 2D) = "white" {}
        _MainTexScale("Main Texture Scale", Range(0,1)) = 0.5
		_NoiseTex("Noise Texture", 2D) = "white" {}
        _Distortion("Noise Scale", range(0,1)) = 0.1
        [HDR]_Color("Tint", Color) = (1, 1, 1, 1)
		_WaveSpeedX("Wave Speed X", Range(0,10)) = 0.5
		_WaveSpeedY("Wave Speed Y", Range(0,10)) = 0.5
		_WaveFreqX("Wave Freq X", Range(0,10)) = 0.6
		_WaveFreqY("Wave Freq Y", Range(0,10)) = 0.6
		_WaveAmp("Wave Height", Range(0,1)) = 0.1
		[HDR]_FresnelColor("FresnelColor",color) = (1,1,1,1)
		_FresnelPower("FresnelPower",Range(0,1)) = 0.5
		_Alpha("Alpha",float) = 1
		_Radius("Radius",Range(0,10)) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Transparent"  "Queue" = "Transparent" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZWrite Off
 
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};
 
			struct v2f
			{
				float2 uv : TEXCOORD2;
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float3 viewDir : POSITION1;
				
			};

            float4 _Color;
			float _Distortion;
			sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
			
            //wave
			float _WaveSpeedX;
			float _WaveSpeedY;
            float _WaveFreqX;
			float _WaveFreqY;
            float  _WaveAmp;
            float _MainTexScale;
			float _FresnelPower;
			float4 _FresnelColor;
			float _FresnelAlpha;
			float _Alpha;

			float fresnel(float3 n, float3 dir, float p)
			{
				return pow(1 - saturate(dot(n,dir)), p);
			}

			sampler2D _CameraDepthTexture;


			v2f vert (appdata v)
			{
				v2f o;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				float4 noise = tex2Dlod(_NoiseTex, float4(o.uv,0,0));
				v.vertex.y += ((sin(_Time.x * _WaveSpeedX + (v.vertex.x * v.vertex.z * _WaveFreqX)) + cos(_Time.y * _WaveSpeedY + (v.vertex.x * v.vertex.z * _WaveFreqY)))) * _WaveAmp * noise;
				o.vertex = UnityObjectToClipPos(v.vertex);

				float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
				float3 d = cameraPos - v.vertex;;
				o.viewDir = normalize(d);


				o.normal = v.normal;
				return o;
			}

			float _Radius;
 
			fixed4 frag (v2f i) : SV_Target
			{
				float2 d = i.uv;
				d.x -= 1;
                float r = d.x * d.x + d.y * d.y;
				if(r > _Radius) discard;
				float distort = tex2D(_NoiseTex, (i.uv * _MainTexScale)  + (_Time.x)).r;
 				float4 col = tex2D(_MainTex, (i.uv * _MainTexScale) - (distort * _Distortion)) * _Color;		
				float4 fr = fresnel(i.normal,i.viewDir,1 - _FresnelPower) * _FresnelColor;
				float depth =  LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv));
				float3 rgb = lerp(col.rgb,fr.rgb,depth);
				float a = lerp(col.a,fr.a,1 - depth) * _Alpha;
				rgb = saturate(rgb);
				return float4(rgb,a);


			}
			ENDCG
		}
	}
}
