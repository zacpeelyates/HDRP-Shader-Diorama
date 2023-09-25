Shader "Unlit/Grid"
{
    Properties
    {
        [HDR]_MainColor ("BG Color", Color) = (1,1,1,1)
        [HDR]_GridColour ("Grid Colour", Color) = (0,0,0,1)
        _Thickness ("Thickness", Range(0,1)) = 0.5
        _Scale ("Scale",float) = 1
        _Emission ("Emission",float) = 1
        _SpeedX("Speed X", Range(-1,1)) = 1
        _SpeedY("Speed Y", Range(-1,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _MainColor;
            float4 _GridColour;
            float _Thickness;
            float _Scale;
            float _Emission;

            v2f vert (appdata v)
            {
                v2f o = (v2f)o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float _SpeedY;
            float _SpeedX;

            float4 frag(v2f i) : SV_Target
            {
                float2 speed = float2(_SpeedX,_SpeedY);
                i.uv += frac(_Time.w * speed);
                i.uv = frac(i.uv * _Scale);
                
                _Thickness = _Thickness /2;
                float3 col = _MainColor.rgb;
                if(i.uv.x < _Thickness || i.uv.y < _Thickness || i.uv.x > (1-_Thickness) ||  i.uv.y > (1-_Thickness)) col = _GridColour * _Emission;
                return float4(col,1);
            }
            ENDCG
        }
    }
}