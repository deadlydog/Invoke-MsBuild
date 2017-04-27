using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SolutionThatShouldBuildWithWarnings
{
    public class Class1
    {
		private void FunctionThatGeneratesAWarning()
		{
			return;
			int unreachableCodeAndUnusedVariableWarningGeneratorLine = 0;
		}
    }
}
