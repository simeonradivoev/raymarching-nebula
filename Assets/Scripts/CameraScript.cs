using UnityEngine;
using System.Collections;

public class CameraScript : MonoBehaviour
{
	public Transform target;
	public Vector3 orbitOffset;
	public float orbitRadius;
	public float orbitSpeed;

	private float angle;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update ()
	{
		transform.position = GetPos(angle);
		transform.LookAt(target);
		angle += Time.deltaTime * orbitSpeed;
	}

	private Vector3 GetPos(float angle)
	{
		return new Vector3(Mathf.Sin(angle) + orbitOffset.x, orbitOffset.y, Mathf.Cos(angle) + orbitOffset.y) * orbitRadius;
	}

	void OnDrawGizmos()
	{
		for (int i = 0; i < 64; i++)
		{
			float step = Mathf.PI * 2 / 64f;
			Gizmos.DrawLine(GetPos(i * step), GetPos((i+1) * step));
		}
	}
}
