	// runc requires cgroupv2 for unified mode
	if isCgroup2UnifiedMode() && !ptr.Deref(m.singleProcessOOMKill, true) {
		resources.Unified = map[string]string{
			// Ask the kernel to kill all processes in the container cgroup in case of OOM.
			// See memory.oom.group in https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html for
			// more info.
			"memory.oom.group": "1",
		}
	}

<https://github.com/kubernetes/kubernetes/blob/v1.33.6/pkg/kubelet/kuberuntime/kuberuntime_container_linux.go#L311-L319>

进程组（Group）级清理： 将 `memory.oom.group` 设置为 `1` 时，如果组内任一进程触发 OOM，内核会结束整个 cgroup（如一个容器）内的所有进程