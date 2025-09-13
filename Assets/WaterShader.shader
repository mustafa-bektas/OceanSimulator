Shader "Custom/WaterShader"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 2)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 10)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float _Amplitude;
            float _Frequency;
            float _Speed;
            
            v2f vert (appdata v)
            {
                v2f o;

                float wave0 = sin(v.vertex.x * _Frequency * 0.8 + v.vertex.z * _Frequency * 0.6 + _Time.y * _Speed) * _Amplitude * 0.6;
                float wave1 = sin(v.vertex.x * _Frequency * 1.2 + v.vertex.z * _Frequency * 0.4 + _Time.y * _Speed * 0.8) * _Amplitude * 0.4;
                float wave2 = sin(v.vertex.x * _Frequency * 0.5 + v.vertex.z * _Frequency * 1.1 + _Time.y * _Speed * 1.3) * _Amplitude * 0.8;
                float wave3 = sin(v.vertex.x * _Frequency * 0.3 + v.vertex.z * _Frequency * 0.7 + _Time.y * _Speed * 0.6) * _Amplitude * 0.3;
                float wavesum = wave0 + wave1 + wave2 + wave3;
                v.vertex.y += wavesum;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(0.1, 0.4, 1.0, 0.0);
            }
            ENDCG
        }
    }
}