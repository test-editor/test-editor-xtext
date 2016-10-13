import org.testeditor.rcp4.*
import org.testeditor.fixture.swt.*

# WriteSimpleTestWithoutPackageTest

//given
config TestEditorConfig

* Given Webproject

	Component: ProjectExplorer
	- Execute menu item "New/Project..." in tree <ProjectTree>

	Component: NewProjectDialog
	- Select element "Test-Editor Project" in tree <ProjectType>
	- Click on <NextButton>
	- Type "MyFirstWebProject" into <ProjectName>
	- Click on <NextButton>
	- Select value "Maven" in combo box <BuildTool>
	- Select element "Web Fixture" in list <AvailableFixturesList>
	- Click on <AddFixtureButton>
	- Check <GenerateWithExamples>
	- Click on <FinishButton>
	- Wait at most "30" seconds until dialog with title "Progress Information" is closed
	// on some machines a dialog pops up that expects to acknowledge a file change for editor refresh
	- Wait at most "5" seconds until dialog with title "File Changed" opens and click "Yes"

	Component: ProjectExplorer
	- Select element "MyFirstWebProject/Tests/MyFirstWebProject" in tree <ProjectTree>
	- Execute menu item "New/Test Case" in tree <ProjectTree>

	Component: NewTestCaseDialog
	- Type "MyTestcase.tcl" into <TestCaseName>
	- Click on <FinishButton>

//when
	Component: ActiveEditor
	- Remove line "1" from editor
	- Save editor content

	Component: MainWindow
	- Wait until all jobs finished

//then
	Component: TestEditorServices
	- Screenshot to "before-verify"

	Component: ActiveEditor
	- isTclPackage = Contains editor "package MyFirstWebProject"
	- assert !isTclPackage
	 
	Component: TestEditorServices
	- isJavaPackage = Contains file "/MyFirstWebProject/src-gen/test/java/MyFirstWebProject/MyTestcase.java" this "package MyFirstWebProject"
	- assert isJavaPackage
