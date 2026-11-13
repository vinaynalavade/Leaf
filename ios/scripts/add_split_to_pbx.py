import re

def update_pbx():
    with open('Leaf.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
        pbx = f.read()

    new_files = [
        # Domain Model (group 5011)
        (1090, 2091, "NetBalanceEngine.swift", 5011, "Leaf"),

        # UseCases (group 5013)
        (1091, 2092, "CreateSplitExpenseUseCase.swift", 5013, "Leaf"),
        (1092, 2093, "UpdateSplitExpenseUseCase.swift", 5013, "Leaf"),
        (1093, 2094, "DeleteSplitExpenseUseCase.swift", 5013, "Leaf"),
        (1094, 2095, "GetSplitSummaryUseCase.swift", 5013, "Leaf"),

        # Split Presentation & Sheets (group 5023)
        (1095, 2096, "SplitLandingViewModel.swift", 5023, "Leaf"),
        (1096, 2097, "SplitLandingView.swift", 5023, "Leaf"),
        (1097, 2098, "CreateSplitSheet.swift", 5023, "Leaf"),
        (1098, 2099, "SplitDetailView.swift", 5023, "Leaf"),
        (1099, 2100, "EditSplitSheet.swift", 5023, "Leaf"),

        # Split Components (group 5024)
        (1100, 2101, "SplitFinancialOverviewCardView.swift", 5024, "Leaf"),
        (1101, 2102, "SplitExpenseCardView.swift", 5024, "Leaf"),

        # Tests (group 5003)
        (1102, 2103, "SplitViewModelTests.swift", 5003, "LeafTests"),
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
    model_children = "\n".join([f"\t\t\t\t{fr_id} /* {fname} */," for _, fr_id, fname, gid, _ in new_files if gid == 5011])
    target_str = "2077 /* TransactionFilter.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{model_children}")

    # 4. Add to UseCase Group (5013)
    usecase_children = "\n".join([f"\t\t\t\t{fr_id} /* {fname} */," for _, fr_id, fname, gid, _ in new_files if gid == 5013])
    target_str = "2080 /* GetCategorySpendingUseCase.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{usecase_children}")

    # 5. Add to LeafTests Group (5003)
    target_str = "2090 /* ExpensesViewModelTests.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2103 /* SplitViewModelTests.swift */,")

    # 6. Add Split group to Presentation Group (5014)
    target_str = "5021 /* Expenses */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t5023 /* Split */,")

    # Add 5023 and 5024 PBXGroup definitions before /* End PBXGroup section */
    split_group_def = """\t\t5023 /* Split */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t2096 /* SplitLandingViewModel.swift */,
\t\t\t\t2097 /* SplitLandingView.swift */,
\t\t\t\t2098 /* CreateSplitSheet.swift */,
\t\t\t\t2099 /* SplitDetailView.swift */,
\t\t\t\t2100 /* EditSplitSheet.swift */,
\t\t\t\t5024 /* Components */,
\t\t\t);
\t\t\tpath = Split;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t5024 /* Components */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t2101 /* SplitFinancialOverviewCardView.swift */,
\t\t\t\t2102 /* SplitExpenseCardView.swift */,
\t\t\t);
\t\t\tpath = Components;
\t\t\tsourceTree = "<group>";
\t\t};\n"""

    pbx = pbx.replace("/* End PBXGroup section */", split_group_def + "/* End PBXGroup section */")

    # 7. Add to PBXSourcesBuildPhase for Leaf (8001)
    leaf_sources = "\n".join([f"\t\t\t\t{bf_id} /* {fname} in Sources */," for bf_id, _, fname, _, tgt in new_files if tgt == "Leaf"])
    target_str = "1088 /* ExpensesSearchBarView.swift in Sources */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{leaf_sources}")

    # 8. Add to PBXSourcesBuildPhase for LeafTests (8002)
    target_str = "1089 /* ExpensesViewModelTests.swift in Sources */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t1102 /* SplitViewModelTests.swift in Sources */,")

    with open('Leaf.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
        f.write(pbx)

    print("Successfully updated project.pbxproj with all 13 Split & Collect module files!")

if __name__ == '__main__':
    update_pbx()

