import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { CategoriesComponent } from './categories/categories.component';
import { ExpenseComponent } from './expense/expense.component';
import { ExpensesComponent } from './expenses/expenses.component';

const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'expense', component: ExpenseComponent },
  { path: 'expenses', component: ExpensesComponent },
  { path: 'categories', component: CategoriesComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
