def update_pbx():
    with open('Leaf.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
        pbx = f.read()

    new_files = [
        # (bf_id, fr_id, fname, gid, target)
        (1103, 2104, "SplitPayment.swift", 5011, "Leaf"),
        (1104, 2105, "SplitPaymentRecord.swift", 5015, "Leaf"),
        (1105, 2106, "RecordParticipantPaymentUseCase.swift", 5013, "Leaf"),
        (1106, 2107, "ReverseParticipantPaymentUseCase.swift", 5013, "Leaf"),
        (1107, 2108, "RecordPaymentSheet.swift", 5023, "Leaf"),
    ]

    # 1. PBXBuildFile section
    build_file_entries = ""
    for bf_id, fr_id, fname, _, _ in new_files:
        build_file_entries += f"\t\t{bf_id} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr_id} /* {fname} */; }};\n"

    pbx = pbx.replace(
        "/* End PBXBuildFile section */",
        build_file_entries + "/* End PBXBuildFile section */"
    )

    # 2. PBXFileReference section
    file_ref_entries = ""
    for _, fr_id, fname, _, _ in new_files:
        file_ref_entries += f"\t\t{fr_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};\n"

    pbx = pbx.replace(
        "/* End PBXFileReference section */",
        file_ref_entries + "/* End PBXFileReference section */"
    )

    # 3. Add to Model Group (5011)
    target_str = "2091 /* NetBalanceEngine.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2104 /* SplitPayment.swift */,")

    # 4. Add to Record Group (5015)
    target_str = "2040 /* TransactionRecord.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2105 /* SplitPaymentRecord.swift */,")

    # 5. Add to UseCase Group (5013)
    target_str = "2095 /* GetSplitSummaryUseCase.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2106 /* RecordParticipantPaymentUseCase.swift */,\n\t\t\t\t2107 /* ReverseParticipantPaymentUseCase.swift */,")

    # 6. Add to Split Group (5023)
    target_str = "2100 /* EditSplitSheet.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2108 /* RecordPaymentSheet.swift */,")

    # 7. Add to PBXSourcesBuildPhase for Leaf (8001)
    leaf_sources = "\n".join([f"\t\t\t\t{bf_id} /* {fname} in Sources */," for bf_id, _, fname, _, _ in new_files])
    target_str = "1101 /* SplitExpenseCardView.swift in Sources */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{leaf_sources}")

    with open('Leaf.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
        f.write(pbx)

    print("Successfully updated project.pbxproj with all 5 partial payment files!")

if __name__ == '__main__':
    update_pbx()

