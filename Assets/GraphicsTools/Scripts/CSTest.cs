
using UnityEngine;
using UnityEngine.Rendering;
using CoreFramework.GraphicsTools;

public class CSTest : MonoBehaviour
{
    public ComputeShader m_ComputeShader = null;
    public Texture2D m_SrcTexture = null;
    public RenderTexture m_RenderTexture = null;

    private int kernel = 0;

    private bool m_ExcuteCommand = false;

    // Start is called before the first frame update
    private void Start()
    {
        kernel = m_ComputeShader.FindKernel("CSMain");
        RestRT();
    }

    private void OnEnable()
    {
        RenderPipelineManager.beginCameraRendering += ExcuteCSCommand;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= ExcuteCSCommand;
    }

    private void OnGUI()
    {
        if (GUI.Button(new Rect(Screen.width - 100, 0, 100, 50), "手动执行CS"))
        {
            ExcuteCSManual();
        }
        else if (GUI.Button(new Rect(Screen.width - 100, 50, 100, 50), "执行Command"))
        {
            m_ExcuteCommand = true;
        }

        float scale = 0.2f;
        GUI.DrawTexture(new Rect(0, 0, m_RenderTexture.width * scale, m_RenderTexture.height * scale), m_RenderTexture);
    }

    private void RestRT()
    {
        m_RenderTexture = new RenderTexture(m_SrcTexture.width, m_SrcTexture.height, 0);
        m_RenderTexture.enableRandomWrite = true;
        m_RenderTexture.Create();
    }

    private void ExcuteCSManual()
    {
        CSDebug.ComputeShaderDebugSet("Debug1", m_ComputeShader, kernel);
        CSDebug.ComputeShaderDebugSet("Debug2", m_ComputeShader, kernel);

        m_ComputeShader.SetTexture(kernel, "Result", m_RenderTexture);
        m_ComputeShader.SetTexture(kernel, "Source", m_SrcTexture);
        m_ComputeShader.Dispatch(kernel, m_RenderTexture.width, m_RenderTexture.height, 1);

        Debug.Log("CS1 : " + CSDebug.ComputeShaderDebugGet("Debug1"));
        Debug.Log("CS2 : " + CSDebug.ComputeShaderDebugGet("Debug2"));

        CSDebug.ComputeShaderDebugRelease();
    }

    private void ExcuteCSCommand(ScriptableRenderContext context, Camera camera)
    {
        if (camera == Camera.main)
        {
            if (m_ExcuteCommand)
            {
                m_ExcuteCommand = false;
            }
            else
            {
                return;
            }
            Debug.Log("CS1 : " + CSDebug.ComputeShaderDebugGet("Debug1"));
            Debug.Log("CS2 : " + CSDebug.ComputeShaderDebugGet("Debug2"));
            CSDebug.ComputeShaderDebugRelease();

            CommandBuffer command = CommandBufferPool.Get("ExcuteCSCommand");
            CSDebug.ComputeShaderDebugSet("Debug1", m_ComputeShader, kernel);
            CSDebug.ComputeShaderDebugSet("Debug2", m_ComputeShader, kernel);

            command.SetComputeTextureParam(m_ComputeShader, kernel, "Result", m_RenderTexture);
            command.SetComputeTextureParam(m_ComputeShader, kernel, "Source", m_SrcTexture);
            command.DispatchCompute(m_ComputeShader, kernel, m_RenderTexture.width, m_RenderTexture.height, 1);

            context.ExecuteCommandBuffer(command);
            CommandBufferPool.Release(command);
        }
    }

}
