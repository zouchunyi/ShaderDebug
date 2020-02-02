
using UnityEngine;

namespace CoreFramework.GraphicsTools
{
    [ExecuteInEditMode]
    public class VertexDebug : MonoBehaviour
    {
        private readonly static int m_ShaderVertexDebugParams = Shader.PropertyToID("_VertexDebugParams");
      
        private Vector2 m_ManualPosition;
        private bool m_ControlPressed = false;

        private float m_DisplayTime = 0f;

        private void Awake()
        {
            m_ManualPosition = Vector2.zero;
            Analyze();
        }

        private void OnGUI()
        {
            if (m_DisplayTime > 0)
            {
                m_DisplayTime -= Time.deltaTime;
                if (GUI.Button(new Rect(Screen.width - 300, 500, 300, 50), "点击屏幕，采集顶点信息"))
                {

                }
            }
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.LeftAlt))
            {
                m_ControlPressed = true;
                m_DisplayTime = 3f;
            }

            if (Input.GetKeyUp(KeyCode.LeftAlt))
            {
                m_ControlPressed = false;
                m_DisplayTime = 0;
            }
            if (m_ControlPressed)
            {
                if (Input.GetMouseButtonDown(0))
                {
                    m_ManualPosition = Input.mousePosition;
                    Analyze();
                }
            }
        }

        private void Analyze()
        {
            Shader.SetGlobalVector(m_ShaderVertexDebugParams, new Vector4(m_ManualPosition.x, m_ManualPosition.y, Screen.width, Screen.height));
        }
    }
}


