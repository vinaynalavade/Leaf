import re

def update_pbx():
    with open('Leaf.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
        pbx = f.read()

    # Define new files to add
    # (bf_id, fr_id, filename, group_id, target: 'Leaf' or 'LeafTests')
    # Let's use IDs starting at 1074 for PBXBuildFile, 2075 for PBXFileReference
    new_files = [
        # Models (group 5011)
        (1074, 2075, "CategorySpending.swift", 5011, "Leaf"),
        (1075, 2076, "MonthlyExpenseSummary.swift", 5011, "Leaf"),
        (1076, 2077, "TransactionFilter.swift", 5011, "Leaf"),

        # UseCases (group 5013)
        (1077, 2078, "UpdateTransactionUseCase.swift", 5013, "Leaf"),
        (1078, 2079, "GetMonthlyExpenseSummaryUseCase.swift", 5013, "Leaf"),
        (1079, 2080, "GetCategorySpendingUseCase.swift", 5013, "Leaf"),

        # Expenses Main & Sheets (group 5021)
        (1080, 2081, "ExpensesView.swift", 5021, "Leaf"),
        (1081, 2082, "ExpensesViewModel.swift", 5021, "Leaf"),
        (1082, 2083, "ExpensesFilterSheet.swift", 5021, "Leaf"),
        (1083, 2084, "AddEditExpenseSheet.swift", 5021, "Leaf"),

        # Expenses Components (group 5022)
        (1084, 2085, "ExpensesMonthPickerHeaderView.swift", 5022, "Leaf"),
        (1085, 2086, "ExpensesMonthlySummaryCardView.swift", 5022, "Leaf"),
        (1086, 2087, "ExpensesCategoryBreakdownView.swift", 5022, "Leaf"),
        (1087, 2088, "ExpensesTransactionHistoryView.swift", 5022, "Leaf"),
        (1088, 2089, "ExpensesSearchBarView.swift", 5022, "Leaf"),

        # LeafTests (group 5003)
        (1089, 2090, "ExpensesViewModelTests.swift", 5003, "LeafTests"),
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
    target_str = "2057 /* BudgetProgress.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{model_children}")

    # 4. Add to UseCase Group (5013)
    usecase_children = "\n".join([f"\t\t\t\t{fr_id} /* {fname} */," for _, fr_id, fname, gid, _ in new_files if gid == 5013])
    target_str = "2063 /* GetBudgetProgressUseCase.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{usecase_children}")

    # 5. Add to LeafTests Group (5003)
    target_str = "2074 /* DashboardViewModelTests.swift */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t2090 /* ExpensesViewModelTests.swift */,")

    # 6. Add Expenses groups (5021, 5022) and link to Presentation (5014)
    # Add 5021 to 5014 Presentation
    target_str = "5020 /* Entry */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t5021 /* Expenses */,")

    # Add 5021 and 5022 PBXGroup definitions before /* End PBXGroup section */
    expenses_group_def = """\t\t5021 /* Expenses */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t2081 /* ExpensesView.swift */,
\t\t\t\t2082 /* ExpensesViewModel.swift */,
\t\t\t\t2083 /* ExpensesFilterSheet.swift */,
\t\t\t\t2084 /* AddEditExpenseSheet.swift */,
\t\t\t\t5022 /* Components */,
\t\t\t);
\t\t\tpath = Expenses;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t5022 /* Components */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t2085 /* ExpensesMonthPickerHeaderView.swift */,
\t\t\t\t2086 /* ExpensesMonthlySummaryCardView.swift */,
\t\t\t\t2087 /* ExpensesCategoryBreakdownView.swift */,
\t\t\t\t2088 /* ExpensesTransactionHistoryView.swift */,
\t\t\t\t2089 /* ExpensesSearchBarView.swift */,
\t\t\t);
\t\t\tpath = Components;
\t\t\tsourceTree = "<group>";
\t\t};\n"""

    pbx = pbx.replace("/* End PBXGroup section */", expenses_group_def + "/* End PBXGroup section */")

    # 7. Add to PBXSourcesBuildPhase for Leaf (8001)
    leaf_sources = "\n".join([f"\t\t\t\t{bf_id} /* {fname} in Sources */," for bf_id, _, fname, _, tgt in new_files if tgt == "Leaf"])
    target_str = "1072 /* DashboardView.swift in Sources */,"
    pbx = pbx.replace(target_str, f"{target_str}\n{leaf_sources}")

    # 8. Add to PBXSourcesBuildPhase for LeafTests (8002)
    target_str = "1073 /* DashboardViewModelTests.swift in Sources */,"
    pbx = pbx.replace(target_str, f"{target_str}\n\t\t\t\t1089 /* ExpensesViewModelTests.swift in Sources */,")

    with open('Leaf.xcodeproj/project.pbxproj', 'w', encoding='utf-8') as f:
        f.write(pbx)

    print("Successfully updated project.pbxproj with all 16 Expenses module files!")

if __name__ == '__main__':
    update_pbx()

