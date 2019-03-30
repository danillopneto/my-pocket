import { Component, OnInit } from '@angular/core';
import { MatTableDataSource } from '@angular/material';
import { ExpensesService } from '../services/expense.service';
import { UtilityService } from '../services/utility.service';
import { Expense } from '../models/expense.model';
import { CategoriesService } from '../services/categories.service';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-expenses',
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.scss']
})
export class ExpensesComponent implements OnInit {
  displayedColumns: string[] = ['day', 'category', 'description', 'value', 'paymentMethod'];
  dataSource: MatTableDataSource<Expense>;
  expenses: Expense[];

  constructor(
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService) { }

  ngOnInit() {
    this.getExpenses();
  }

  applyFilter(filterValue: string) {
    this.dataSource.filter = filterValue.trim().toLowerCase();
  }

  getExpenses() {
    this.util.showLoading();
    this.expensesService.getAll().subscribe(data => {
      this.expenses = data;
      this.dataSource = new MatTableDataSource(this.expenses);
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  getCategory(idCategory: string) {
    return this.categoriesService.get(idCategory).subscribe(data => {
      return data;
    });
  }
}
