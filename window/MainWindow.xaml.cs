using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace Deploymentor
{
    /// <summary>
    /// Interaktionslogik für MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void DoInstallAll_Click(object sender, RoutedEventArgs e)
        {
            var z = new ListViewItem();

        }


        private void DoInstallSoftware_Click(object sender, RoutedEventArgs e)
        {
            lvSoftware.Items.Clear();
            lvSoftware.Items.Add(new { Name = "hi", Description = "ho" });
            lvSoftware.Items.Add(new { Name = "hi", Description = "ho" });
            lvSoftware.Items.Add(new { Name = "hi", Description = "ho" });
        }

        private void DoInstallActions_Click(object sender, RoutedEventArgs e)
        {
            lvActions.Items.Clear();
            lvActions.Items.Add(new { Name = "hi", Description = "ho" });
            lvActions.Items.Add(new { Name = "hi", Description = "ho" });
            lvActions.Items.Add(new { Name = "hi", Description = "ho" });
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {

        }

        private void CbProfileSelect_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            
        }

        private void LvTools_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {

        }

        private void DoActionsDir_Click(object sender, RoutedEventArgs e)
        {

        }

        private void DoSoftwareDir_Click(object sender, RoutedEventArgs e)
        {

        }

        private void DoOpenConfig_Click(object sender, RoutedEventArgs e)
        {

        }

        private void LbCopy_MouseDown(object sender, MouseButtonEventArgs e)
        {

        }
    }
}
