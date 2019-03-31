import { Component, OnInit, ViewChild } from '@angular/core';
import { MatTableDataSource, MatSort } from '@angular/material';
import { ExpensesService } from '../services/expense.service';
import { UtilityService } from '../services/utility.service';
import { Expense } from '../models/expense.model';
import { CategoriesService } from '../services/categories.service';

@Component({
  selector: 'app-expenses',
  templateUrl: './expenses.component.html',
  styleUrls: ['./expenses.component.scss']
})
export class ExpensesComponent implements OnInit {
  displayedColumns: string[] = ['day', 'category', 'description', 'value', 'paymentMethod', 'edit', 'remove'];
  dataSource: MatTableDataSource<Expense>;
  @ViewChild(MatSort) sort: MatSort;
  
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
    this.expensesService.getAllWithQuery((x => x.orderBy('day', 'desc')))
          .subscribe(data => {
      this.expenses = data;
      this.dataSource = new MatTableDataSource(this.expenses);      
      this.dataSource.sort = this.sort;
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  getTotalCost() {
    if (this.expenses != null) {
      return this.expenses.map(t => t.value).reduce((acc, value) => acc + value, 0);
    }

    return '';
  }

  getCategory(idCategory: string) {
    return this.categoriesService.get(idCategory).subscribe(data => {
      return data;
    });
  }

  removeExpense(id: string) {
    this.util.showLoading();
    this.expensesService
      .remove(id)
      .catch(() => {        
      })
      .finally(() => {
        this.util.hideLoading();
      });
  }
}
