using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Translating : MonoBehaviour
{
    public Vector3 startPoint = Vector3.zero;
	public Vector3 endPoint = Vector3.zero;
	public Vector3 lookAt = Vector3.zero;
	public bool pingpong = true;
    public float speed = 10.0f;

    private Vector3 curEndPoint = Vector3.zero;

    // Start is called before the first frame update
    void Start()
    {
        transform.position = startPoint;
		curEndPoint = endPoint;
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = Vector3.Slerp(transform.position, curEndPoint, Time.deltaTime * speed);
		transform.LookAt(lookAt);
		if (pingpong) 
        {
			if (Vector3.Distance(transform.position, curEndPoint) < 0.001f) 
            {
				curEndPoint = Vector3.Distance(curEndPoint, endPoint) < Vector3.Distance(curEndPoint, startPoint) ? startPoint : endPoint;
			}
		}
    }
}
