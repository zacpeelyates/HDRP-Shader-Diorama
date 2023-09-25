Shader "Unlit/GoochShader"
{
   Properties
    {
        _MainColor("Main Color",color) = (1,1,1,1)
        _WarmColor("Warm Color",color) = (1,0,1,1)
        _WarmBlend("Warm Blend",Range(0,1)) = 0.5
        _CoolColor("Cool Color",color) = (0,0,0,1)
        _CoolBlend("Cool Blend",Range(0,1)) = 0.5
        _SpecularExponent("SpecularExponent",Range(1,128)) = 64
    }

    SubShader 
    {

    

        Tags 
        {
          "RenderType" = "Opaque"
        } 
        LOD 100

        Pass //gooch pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 worldPosition : POSITION1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal; 
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex).xyz;
    
                return o;
            }

            float4 _WarmColor;
            float4 _CoolColor;
            float4 _MainColor;
            float _WarmBlend;
            float _CoolBlend;
            float _SpecularExponent;

            float3 _MainLightDirection ;
            float4 _MainLightColor;
         
   

            fixed4 frag (v2f i) : SV_Target
            {


                //blinn-phong
                float3 lightDir = normalize(_MainLightDirection);
                float3 viewDir = _WorldSpaceCameraPos.xyz - i.worldPosition;
                //gooch
                float g = (dot(lightDir,i.normal) + 1) / 2;
                float3 warm = _WarmColor + _WarmBlend * _MainColor;
                float3 cool = _CoolColor + _CoolBlend * _MainColor;
                float3 diffuse = (g * cool) + ((1-g) * warm);
                //specular
                float3 reflectDir =  reflect(lightDir,i.normal);
                float3 spec =  pow(DotClamped(normalize(viewDir),normalize(reflectDir)), _SpecularExponent) * _MainLightColor; //appply spec to upper hemisphere
                spec = lerp(0,spec,clamp(i.uv.y - 0.5, 0,1));
                return float4(diffuse + spec,1);

            }
            ENDCG
        }
    }

}




 