# KB5028997 - windows update fails

The recovery partition might be too small - note this guide assumes the disk is in GPT mode (default) - if it's in MBR mode, this will fail!

1. Stop recovery agent: `reagentc /disable`
2. Run **cmd.exe** as admin
3. Start `Diskpart`
4. Run `list disk`  
  Note the disk with your OS (likely there is just one disk)
5. Select the disk `sel disk 0`
6. List partitions `list par` on the selected disk. Take note of the OS disk (likely par 3)
7. Select OS partition `sel par 3`
8. Shrink the partition `shrink desired=250 minimum=250`
9. Select the Recovery partition `sel par 4`
10. Delete the recovery partition `delete partition override`
11. Create new recover partition `create partition primary id=de94bba4-06d1-4d40-a16a-bfd50179d6ac`
12. Set attributes `gpt attributes =0x8000000000000001`
13. Format partition `format quick fs=ntfs label=”Windows RE tools”`
14. Exit diskpart `exit`
15. Re-enable recovery agent `reagentc /enable`
16. Windows updates should now work..