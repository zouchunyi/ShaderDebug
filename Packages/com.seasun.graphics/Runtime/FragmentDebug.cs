
using UnityEngine;

namespace CoreFramework.GraphicsTools
{
    public class FragmentDebug : MonoBehaviour
    {
        private const string SHOW_KEY = "FragmentDebugShow";
        private enum State
        {
            Auto,
            Manual
        }

#if FRAGMENG_DEBUG
        private const string FRAGMENG_DEBUG_ENABLE = "FRAGMENT_DEBUG_ENABLE";
        private readonly static int m_ShaderPropertyIDDebugValue = Shader.PropertyToID("_DebugValue");
        private readonly static int m_ShaderPropertyIDSourceTexture = Shader.PropertyToID("_SourceTexture");
        private readonly static int m_ShaderPropertyIDDebugPosition = Shader.PropertyToID("_DebugPosition");
        private readonly static int m_ShaderPropertyDebugTexture = Shader.PropertyToID("_CameraDebugTexture");

        private ComputeShader m_ComputeShader = null;
        private State m_State = State.Manual;

        private RenderTexture m_RT = null;
        private int m_RTWidth = 0;
        private int m_RTHeight = 0;
        private Vector2 m_ManualPosition;
        private bool m_ControlPressed = false;
        private float m_DisplayTime = 0f;

        private float[] m_Values = new float[5] { 0, 0, 0, 0, 0 };

#endif
        private void Awake()
        {
#if FRAGMENG_DEBUG
            m_ComputeShader = Resources.Load<ComputeShader>("FragmentTextureAnalyze");
            Shader.EnableKeyword("FRAGMENT_DEBUG_ENABLE");
#else
            Shader.DisableKeyword("FRAGMENT_DEBUG_ENABLE");
#endif
        }

#if FRAGMENG_DEBUG

        private void OnGUI()
        {
            if (PlayerPrefs.GetInt(SHOW_KEY, 1) > 0)
            {
                if (!m_Values[0].Equals(0) || m_Values[1].Equals(0))
                {
                    string str = "X:" + m_Values[0] + "\nY:" + m_Values[1] + "\n" + m_Values[2].ToString() + "\n" + m_Values[3] + "\n" + m_Values[4];
                    if (GUI.Button(new Rect(Screen.width - 200, 200, 120, 120), str))
                    {

                    }
                }
            }

            if (m_DisplayTime > 0)
            {
                m_DisplayTime -= Time.deltaTime;
                if (GUI.Button(new Rect(Screen.width - 300, 400, 300, 50), "点击屏幕，采集像素点信息"))
                {

                }
            }
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.LeftControl))
            {
                m_ControlPressed = true;
                m_DisplayTime = 3f;
            }

            if (Input.GetKeyUp(KeyCode.LeftControl))
            {
                m_ControlPressed = false;
                m_DisplayTime = 0;
            }

            if (m_ControlPressed)
            {
                if (Input.GetMouseButtonDown(0))
                {
                    m_State = State.Manual;
                    m_ManualPosition = Input.mousePosition;
                    Analyze();
                }

                if (Input.GetKeyDown(KeyCode.A))
                {
                    m_State = State.Auto;
                    Analyze();
                }

                if (Input.GetKeyDown(KeyCode.D))
                {
                    PlayerPrefs.SetInt(SHOW_KEY, 1 - PlayerPrefs.GetInt(SHOW_KEY, 1));
                }
            }
        }

        private void Analyze()
        {
            int kernel = 0;
            if (m_State == State.Manual)
            {
                kernel = 1;
            }

            float[] values = new float[5] { 0, 0, 0, 0, 0 };
            ComputeBuffer buffer = null;
            buffer = new ComputeBuffer(values.Length, 4);
            buffer.SetData(values);

            if (m_State == State.Manual)
            {
                m_ComputeShader.SetVector(m_ShaderPropertyIDDebugPosition, new Vector4(m_ManualPosition.x, m_ManualPosition.y, 0, 0));
            }
            m_ComputeShader.SetBuffer(kernel, m_ShaderPropertyIDDebugValue, buffer);
            m_ComputeShader.SetTextureFromGlobal(kernel, m_ShaderPropertyIDSourceTexture, m_ShaderPropertyDebugTexture);
            m_ComputeShader.Dispatch(kernel, Screen.width, Screen.height, 1);
            buffer.GetData(values);
            buffer.Release();

            if (!(values[0].Equals(0) && values[0].Equals(0)))
            {
                values.CopyTo(m_Values, 0);
                Debug.Log("Screen Position: " + values[0] + "," + values[1] + " ; Value1: " + values[2] + " , Value2: " + values[3] + " , Value3: " + values[4]);
            }
        }
#endif
    }
}


