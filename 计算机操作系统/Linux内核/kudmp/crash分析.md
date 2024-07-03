- `Kernel panic - not syncing: stack-protector: Kernel stack is corrupted in`

```bash
crash> bt
PID: 2759     TASK: ffff8d8c4800a0e0  CPU: 1    COMMAND: "bpbkar"
 #0 [ffff8d94a52d37b0] machine_kexec at ffffffff82c65754
 #1 [ffff8d94a52d3810] __crash_kexec at ffffffff82d209a2
 #2 [ffff8d94a52d38e0] panic at ffffffff833728ec
 #3 [ffff8d94a52d3960] __stack_chk_fail at ffffffff82c9a5eb
 #4 [ffff8d94a52d3970] kernel_rule_log_filter at ffffffffc078b623 [sysmon_edr] <<------
 #5 [ffff8d94a52d3bb0] Kernel_Rule_Log_Proc at ffffffffc078b899 [sysmon_edr] <<------
 #6 [ffff8d94a52d3ca0] wgs_check_file at ffffffffc078b9a4 [sysmon_edr] <<------
 #7 [ffff8d94a52d3cf8] check_file_input at ffffffffc0788706 [sysmon_edr] <<------
 #8 [ffff8d94a52d3d60] hook_security_inode_setattr at ffffffffc0788b12 [sysmon_edr] <<------
 #9 [ffff8d94a52d3d80] security_inode_setattr at ffffffff82f0189f
#10 [ffff8d94a52d3da0] notify_change at ffffffff82e67a9b
#11 [ffff8d94a52d3de8] utimes_common at ffffffff82e7df99
#12 [ffff8d94a52d3e78] do_utimes at ffffffff82e7e165

crash> dis -rl ffffffffc078b623 | tail

crash> dis -rl ffffffff82c9a5eb

crash> mod -t 
```

